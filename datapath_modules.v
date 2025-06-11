
module inst_mem(clk, addr, inst); //size 256x32
    input clk;
    input [7:0] addr;
    output [31:0] inst; // Should be 'output' for combinational read

    reg [31:0] mem [0:255]; // Instruction memory array

    // Combinational read: output reflects memory content immediately based on address
    assign inst = mem[addr];

endmodule

module reg_file(clk, wrt, rd, rs, rt, data_in, rs_out, rt_out); //size 64x32
    input clk, wrt;
    input [5:0] rd, rs, rt;
    input [31:0] data_in;
    output [31:0] rs_out, rt_out;

    reg [31:0] rf [0:63]; // Register file array

    integer i;
    initial begin
        for(i = 0; i<64; i=i+1) rf[i] = 0;
	    rf[10] = 32'd0;    // x10 = &a[0] -> DM address 0
        //rf[2] = 32'd0;    // x2 = Start index = 0
        rf[11] = 32'd6;    // x3 = End index = 3 (array size of 3, iterating 0, 1, 2, then 3 exits)
    end

    assign rs_out = rf[rs];
    assign rt_out = rf[rt];
    	
    always@(rs, rt) $display("READ: Rs = x%0d (%0d), Rt = x%0d (%0d) at time %t", rs, $signed(rs_out), rt, $signed(rt_out), $time);
    // Synchronous write: Register file content is updated on positive clock edge if write enable is high
    always @(posedge clk) begin
        if (wrt==1) begin
            rf[rd] <= data_in;
        end
    end
endmodule

module and3(input a, input b, input c, output y);
    assign y = a && b && c;
endmodule


module data_mem(clk, r, w, addr, data_in, data_out); //size 65536x32
    input clk, r, w;
    input [31:0] addr, data_in;
    output reg [31:0] data_out;

    reg [31:0] d_mem [0:65535];
    wire [15:0] a = addr[15:0]; //made inst_mem word addressed so use 16 bits here

    initial begin
        d_mem[16'd2] = 32'd31;    // a[2]
        d_mem[16'd3] = 1024;
        d_mem[16'd4] = 32'd9;
        d_mem[16'd5] = -32'd2048;
        d_mem[16'd6] = 32'd10;
    end

    always @(posedge clk) begin
        if (w) begin
		  d_mem[a] <= data_in;
        end
        else if (r) begin
            data_out <= d_mem[a];
        end
    end
endmodule

module PC(clk, in, out);
	input clk;
	input [31:0] in;
	output reg [31:0] out;
	
	initial begin
		out = 0;
	end
	
	always@(posedge clk) 
	begin
	   if(in)
		  out = in;
	end
endmodule

module imm_gen(instruct_in, instruct_out, clk); 

    input [31:0] instruct_in; 
	input clk;
    output reg [31:0] instruct_out; 
    
    always@(posedge clk)
    begin
        if(instruct_in[31:28] == 4'b1111)
        begin          
            instruct_out[31:0] <= { {22{instruct_in[21]}}, instruct_in[21:0]};
        end
        else if(instruct_in[31:28] == 4'b0101)
        begin
            instruct_out[31:0] <= { {16{instruct_in[15]}}, instruct_in[15:0]};
        // OR instruct_out <= $signed(instruct_in); 
        end
        else
        begin
            instruct_out = instruct_in;
        end
    end
endmodule

