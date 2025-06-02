module ifid_buf(clk, instr_in, pc_in, instr_out, pc_out);
    input clk;
    input [31:0] instr_in, pc_in;
    output reg [31:0] instr_out, pc_out;
    always @(posedge clk) begin
	instr_out <= instr_in;
	pc_out <= pc_in;
    end
endmodule

module idex_buf(clk, pc_in, rs_in, rt_in, rd_in, rs_out, rt_out, rd_out, pc_out, imm_in, imm_out);
    input clk;
    input [31:0] pc_in, rs_in, rt_in, imm_in;
    input [5:0] rd_in;
    output reg [31:0] pc_out, rs_out, rt_out, imm_out;
    output reg [5:0] rd_out;
    always @(posedge clk) begin
        pc_out <= pc_in;
        rs_out <= rs_in;
        rt_out <= rt_in;
        rd_out <= rd_in;
	imm_out <= imm_in;
    end
endmodule

module exmem_buf(clk, pc_in, alu_out_in, rt_in, rd_in, pc_out, alu_out_out, rt_out, rd_out);
    input clk;
    input [31:0] pc_in, alu_out_in, rt_in;
    input [5:0] rd_in;
    output reg [31:0] pc_out, alu_out_out, rt_out;
    output reg [5:0] rd_out;
    always @(posedge clk) begin
        pc_out <= pc_in;
        alu_out_out <= alu_out_in;
        rt_out <= rt_in;
        rd_out <= rd_in;
    end
endmodule

module memwb_buf(clk, data_in, alu_out_in, rd_in, data_out, alu_out_out, rd_out);
    input clk;
    input [31:0] data_in, alu_out_in;
    input [5:0] rd_in;
    output reg [31:0] data_out, alu_out_out;
    output reg [5:0] rd_out;
    always @(posedge clk) begin
        data_out <= data_in;
        alu_out_out <= alu_out_in;
        rd_out <= rd_in;
    end
endmodule

