module pipelined_datapath(input clk);
	reg clk;
	
//*** Stage 1 (IF stage) wires and regs ***
	// pc
	wire [31:0] pc_in, pc_out; //PC output
	// pc_alu_adder
	wire [31:0] pc_alu_adder_out;
	// inst_mem
	wire [31:0] inst_out; //inst_mem output
	
	// IF/ID buffer
	reg [31:0] ifid_pc, ifid_inst;	
	
	
//*** Stage 2 (ID stage) wires and regs ***
 	// reg file
	wire [5:0] rd_in, rs_in, rt_in;
	wire [31:0] data_in;
	wire [31:0] rs_out, rt_out;
	// imm gen
	wire [31:0] imm_out;
 	// control unit
	wire RegWrite, MemRead, MemWrite, ALUSrc, MemToReg;
	wire [1:0] PCSel;
	wire Zflag, Nflag, add, inc, neg, sub;  //Don't thinnk we need Z and N flag in control unit?

	// ID/EX buffer
	reg [31:0] idex_pc, idex_rs, idex_rt, idex_imm;
	reg [5:0] idex_rd;
	reg idex_RegWrite, idex_MemRead, idex_MemWrite, idex_ALUsrc, idex_MemToReg;
	reg [1:0] idex_PCSel;
	reg idex_add, idex_inc, idex_neg, idex_sub;

	
//*** Stage 3 (EX stage) wires and regs ***
	// ex_alu_adder
	wire [31:0] ex_alu_adder_in, ex_alu_adder_out, pc_branch;
	
	// EX/MEM buffer
	reg [31:0] exmem_alu_out, exmem_rt;
	reg [5:0] exmem_rd;
	reg exmem_RegWrite, exmem_MemRead, exmem_MemWrite, exmem_ALUsrc, exmem_MemToReg;

	
//*** Stage 4 (MEM stage) wires and regs ***
	// data_mem
	wire data_out;
	
	// MEM/WB buffer
	reg [31:0] memwb_data_out, memwb_alu_out;
	reg [5:0] memwb_rd;
	reg memwb_RegWrite, memwb_MemToReg;

	
//*** Stage 5 (WB stage) wires and regs ***
	wire [31:0] wb_data;
	
	
//Double check the instatiation of the parameters below
// Instatiate stage 1 (IF stage) modules
	MUX pc_mux(
		.a(pc_alu_adder_out), 
		.b(exmem_alu_out), 
		.sel(PCSel), 
		.out(pc_in)
	);
	PC program_counter(
		.clk(clk), 
		.in(pc_in), 
		.out(pc_out)
	);
	inst_mem inst_mem(
		.clk(clk), 
		.addr(pc_out[7:0]), 
		.inst(inst_out)
	);
	ALU pc_adder(
		.A(pc_out), .B(32'd4), 
		.add(1), .inc(0), .neg(0), .sub(0), 
		.out(pc_alu_adder_out), .Z(), .N()
	);
	
	//update IF/ID buffer
	always @(posedge clk) begin
		ifid_pc <= pc_out;
		ifid_inst <= inst_out;
	end
	
// Instantiate stage 2 (ID stage) modules
	//check drawn datapath for indices
	assign rs_in = ifid_instr[25:20];
	assign rt_in = ifid_instr[19:14];
	assign rd_in = ifid_instr[13:8];

	reg_file reg_file(
		.clk(clk), .wrt(memwb_RegWrite), .rd(memwb_rd), 
		.rs(rs_in), .rt(rt_in), .data_in(data_in), 
		.rs_out(rs_out), .rt_out(rt_out)
	);
	
	imm_gen imm_gen(
		.clk(clk), 
		.in(ifid_inst), 
		.out(imm_out)
	);
	
	ControlUnit ctrl_unit(
		.opcode(ifid_inst[31:26]), 
		.RegWrite(RegWrite), .MemRead(MemRead), .MemWrite(MemWrite),
		.ALUSrc(ALUSrc), .MemToReg(MemToReg), .PCSel(PCSel), .Zflag(), .Nflag(),
		.add(add), .inc(inc), .neg(neg), .sub(sub)
	);  //do we need N and Z flag?
	
	//update ID/EX buffer
	always @(posedge clk) begin
		idex_pc <= IF_ID_pc;
		idex_rs <= rs_out;
		idex_rt <= rt_out;
		idex_imm <= imm_out;
		idex_rd <= rd;
		idex_RegWrite <= RegWrite;
		idex_MemRead <= MemRead;
		idex_MemWrite <= MemWrite;
		idex_ALUSrc <= ALUSrc;
		idex_MemToReg <= MemToReg;
		idex_PCSel <= PCSel;
		idex_add <= add;
		idex_inc <= inc;
		idex_neg <= neg;
		idex_sub <= sub;
	end

// Instantiate stage 3 (EX stage) modules
	ALU ex_alu_adder(
		.A(idex_rs), .B(ex_alu_adder_in), 
		.add(idex_add), .inc(idex_inc), .neg(idex_neg), .sub(idex_sub), 
		.out(ex_alu_adder_out), .Z(), .N()
	);
	MUX alu_src_mux(
		.a(idex_rt), 
		.b(idex_imm), 
		.sel(idex_ALUSrc), 
		.out(ex_alu_adder_in)
	);
	
	//EX/MEM buffer
	always @(posedge clk) begin
		exmem_alu_out <= alu_out;
		exmem_rt <= idex_rt;
		exmem_rd <= idex_rd;
		exmem_RegWrite <= idex_RegWrite;
		exmem_MemRead <= idex_MemRead;
		exmem_MemWrite <= idex_MemWrite;
		exmem_MemToReg <= idex_MemToReg;
	end
	
// Instantiate stage 4 (MEM stage) modules
	data_mem data_mem(
		.clk(clk), 
		.r(exmem_MemRead), 
		.w(exmem_MemWrite), 
		.addr(exmem_alu_out), 
		.data_in(exmem_rt), 
		.data_out(data_out)
	);
	
	//MEM/WB buffer
	always @(posedge clk) begin
		memwb_data_out <= data_out;
		memwb_alu_out <= exmem_alu_out;
		memwb_rd <= exmem_rd;
		memwb_RegWrite <= exmem_RegWrite;
		memwb_MemToReg <= exmem_MemToReg;
	end
	
// Instantiate stage 5 (WB stage) modules
	MUX wb_mux(
		.a(memwb_alu_out), 
		.b(memwb_data_out), 
		.sel(memwb_MemToReg), 
		.out(wb_data)
	);
	
endmodule
