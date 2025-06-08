module ifid_buf(clk, instr_in, pc_in, instr_out, pc_out);
    input clk;
    input [31:0] instr_in, pc_in;
    output reg [31:0] instr_out, pc_out;
    always @(posedge clk) begin
	instr_out <= instr_in;
	pc_out <= pc_in;
    end
endmodule

module idex_buf(clk, pc_in, rs_in, rt_in, imm_in, rd_in, ctrl_in, rs_out, rt_out, rd_out, pc_out, imm_out, ctrl_out);)
    input clk;
    input [31:0] pc_in, rs_in, rt_in, imm_in;
    input [5:0] rd_in;
    input [11:0] ctrl_in;
    output reg [31:0] pc_out, rs_out, rt_out, imm_out;
    output reg [5:0] rd_out;
    output reg [11:0] ctrl_out;
    always @(posedge clk) begin
        pc_out <= pc_in;
        rs_out <= rs_in;
        rt_out <= rt_in;
        rd_out <= rd_in;
	imm_out <= imm_in;
	ctrl_out <= ctrl_in;
    end
endmodule

module exmem_buf(
    input clk,
    // Data inputs
    input Z_in,
    input N_in,
    input [31:0] alu_result_in,
    input [31:0] rt_in,
    input [5:0] rd_in,
    input [31:0] pc_plus_imm_in,
    // Control inputs
    input [2:0] aluOp_in,
    input MemRead_in,
    input MemWrite_in,
    input RegWrite_in,
    input MemToReg_in,
    input PCtoReg_in,
    input BrZ_in,
    input BrN_in,
    input jump_in,
    input jump_mem_in,
    // Data outputs
    output reg Z_out,
    output reg N_out,
    output reg [31:0] alu_result_out,
    output reg [31:0] rt_out,
    output reg [5:0] rd_out,
    output reg [31:0] pc_plus_imm_out,
    // Control outputs
    output reg [2:0] aluOp_out,
    output reg MemRead_out,
    output reg MemWrite_out,
    output reg RegWrite_out,
    output reg MemToReg_out,
    output reg PCtoReg_out,
    output reg BrZ_out,
    output reg BrN_out,
    output reg jump_out,
    output reg jump_mem_out
);

    always @(posedge clk) begin
        // Pass through flags and data
        Z_out <= Z_in;
        N_out <= N_in;
        alu_result_out <= alu_result_in;
        rt_out <= rt_in;
        rd_out <= rd_in;
        pc_plus_imm_out <= pc_plus_imm_in;
        // Pass through control signals
        aluOp_out <= aluOp_in;
        MemRead_out <= MemRead_in;
        MemWrite_out <= MemWrite_in;
        RegWrite_out <= RegWrite_in;
        MemToReg_out <= MemToReg_in;
        PCtoReg_out <= PCtoReg_in;
        BrZ_out <= BrZ_in;
        BrN_out <= BrN_in;
        jump_out <= jump_in;
        jump_mem_out <= jump_mem_in;
    end

endmodule

module memwb_buf(
    input clk,
    input [31:0] data_in,
    input [31:0] alu_result_in,
    input [5:0] rd_in,
    input RegWrite_in,
    input MemToReg_in,
    input PCtoReg_in,
    input BrZ_in,
    input BrN_in,
    input jump_in,
    input jump_mem_in,

    output reg [31:0] data_out,
    output reg [31:0] alu_result_out,
    output reg [5:0] rd_out,
    output reg RegWrite_out,
    output reg MemToReg_out,
    output reg PCtoReg_out,
    output reg BrZ_out,
    output reg BrN_out,
    output reg jump_out,
    output reg jump_mem_out
);

    always @(posedge clk) begin
        data_out <= data_in;
        alu_result_out <= alu_result_in;
        rd_out <= rd_in;

        RegWrite_out <= RegWrite_in;
        MemToReg_out <= MemToReg_in;
        PCtoReg_out  <= PCtoReg_in;
        BrZ_out      <= BrZ_in;
        BrN_out      <= BrN_in;
        jump_out     <= jump_in;
        jump_mem_out <= jump_mem_in;
    end

endmodule
