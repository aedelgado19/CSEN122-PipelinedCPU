//when we say like ifid_blah, that means the blah LEAVES the ifid buffer (not enters)

module pipelined_datapath(input clk);
	
//===================== Stage 1 (IF stage) =====================
	
	//remember to instantiate the mux that has 3 inputs: PC+1, jump, and rs (from ALU), and outputs pc_in !!!!!!!!!!!!!!
	//PC Sel is created in EXMEM stage

	// pc
	wire [31:0] pc_in, pc_out; //PC output
	
	// pc_adder inputs are the PC_out, 1, and outputs pc_plus1
	wire [31:0] pc_plus1;


	// inst_mem takes in PC_out amd outputs inst_out
	wire [31:0] inst_out;
	
	// IF/ID buffer takes in PC, and inst out, and outputs ifid_pc and ifid_inst
	wire [31:0] ifid_pc, ifid_inst;	
	

// Instatiate stage 1 (IF stage) modules
	mux3to1 pc_mux(
		.a(pc_plus1), 
		.b(ALU_result),
		.c(mem_data_out),
		.sel1(pc_sel),  	//pc_sel from mem stage (stage 4), the or and and gates
		.sel2(memwb_ctrl[0]),	//jump_mem control signal
		.out(pc_in)
	);
	PC program_counter(
		.clk(clk), 
		.in(pc_in), 
		.out(pc_out)
	);
	inst_mem inst_mem(
		.clk(clk), 
		.addr(pc_out), 
		.inst(inst_out)
	);
	ALU pc_adder(
		.A(pc_out), .B(32'd1), 
		.aluOp(3'b111), //111 for add 
		.out(pc_plus1), .Z(), .N()
	);
	ifid_buf ific(
		.clk(clk),
		.instr_in(inst_out),
		.pc_in(pc_out),
		
		.instr_out(ifid_inst),
		.pc_out(ifid_pc)
	);
	
	
//===================== Stage 2 (ID stage) wires and regs =====================
 	// reg file
	wire [5:0] rd_in, rs_in, rt_in; //rd_in/memwb_rd comes from writeback out of the MEM/WB buffer
	wire [31:0] write_data, regW; //write data is the data to write, regW comes from stage 5
	wire [31:0] rs_out, rt_out;

	// imm gen
	wire [31:0] imm_out;

 	// control unit, check ctrl.v for indices
 	wire [3:0] opcode;
	wire [11:0] ctrl_out; // updated width for control signals


	// ID/EX buffer inputs
	// (already made) rs_out, rt_out, imm_out, rd, ctrl, ifid_pc

	// ID/EX buffer outputs
	wire [31:0] idex_rs, idex_rt, idex_imm, idex_pc;
	wire [5:0] idex_rd;
	wire [8:0] idex_ctrl;
	

// Instantiate stage 2 (ID stage) modules
	//check drawn datapath for indices
	assign rs_in = ifid_instr[21:16];
	assign rt_in = ifid_instr[15:10];
	assign rd_in = memwb_rd;
	assign opcode = ifid_instr[15:12]; // Extract opcode from instruction
	assign regW = memwb_ctrl[6];  //memwb_ctrl created at stage 5 of this program
	assign write_data = wb_data;  //wb_data created at stage 5 of this program

	reg_file reg_file(
		.clk(clk), .wrt(regW), .rd(rd_in), 
		.rs(rs_in), .rt(rt_in), .data_in(write_data), 
		.rs_out(rs_out), .rt_out(rt_out)
	);
	
	imm_gen imm_gen(
		.clk(clk), 
		.in(ifid_inst), 
		.out(imm_out)
	);
	
	ControlUnit ctrl_unit(
		.opcode(opcode),
		.ctrl_out(ctrl_out)
	);	

	idex_buf idex(
		.clk(clk),
		.pc_in(pc_out),
		.rs_in(rs_out),
		.rt_in(rt_out),
		.imm_in(imm_out),
		.rd_in(memwb_rd),
		.ctrl_in(ctrl_out),
		
		.rs_out(idex_rs),
		.rt_out(idex_rt),
		.rd_out(idex_rd),
		.pc_out(idex_pc),
		.imm_out(idex_imm),
		.ctrl_out(idex_ctrl)
	);
	
	
//===================== Stage 3 (EX stage) wires and regs =====================
	// ex_alu takes in: idex_rs, imm_mux_choice, idex_ALU_OP, and outputs Z, N, and 32bit ALU_result
	wire [31:0] imm_mux_choice, alu_result, pc_branch; //imm_mux_choice is the result of the mux that chooses imm or rt
	

	//dont forget to instantiate the imm_mux
	
	// EX/MEM buffer takes Zflag, Nflag, alu_result, idex_rt, PC + imm, idex_rd, and idex_ctrl except ALU_OP is dc
	wire Zflag, Nflag;
	wire [31:0] pc_plus_imm;


	//EXMEM outputs
	wire [31:0] exmem_alu_result, exmem_rt, exmem_pc_plus_imm;
	wire [5:0] exmem_rd;
	wire [8:0] exmem_ctrl;

// Instantiate stage 3 (EX stage) modules
	ALU ex_alu(
		.A(idex_rs), .B(imm_mux_choice), 
		.aluOp(ctrl[11:9]),
		.out(alu_result), .Z(Zflag), .N(Nflag)
	);
	mux2to1 alu_src_mux(
		.a(idex_rt), 
		.b(idex_imm), 
		.sel(ctrl_out[?]), //ctrl indexed according to order specified above or in ctrl.v
		.out(imm_mux_choice)
	);
	ALU ex_adder(
		.A(idex_pc), .B(idex_imm),
		.aluOp(3'b111),
		.out(pc_plus_imm), .Z(), .N()
	);
	
	//Use this one? Option B (check for another version jsut below)
	exmem_buf exmem(
		.clk(clk),
		.Z_in(Zflag).
		.N_in(Nflag),
		.alu_result_in(alu_result),
		.rt_in(idex_rt),
		.rd_in(idex_rd),
		.pc_plus_imm_in(pc_plus_imm),
		.ctrl_in(idex_ctrl[11:0],
		
		.Z_out(Zflag),
		.N_out(Nflag),
		.alu_result_out(exmem_alu_result),
		.rt_out(exmem_rt),
		.rd_out(exmem_rd),
		.pc_plus_imm_out(exmem_pc_plus_imm)
		.ctrl_out(exmem_ctrl)
	);
	
	//or this one? Option B
	exmem_buf exmem2(
		.clk(clk),
		.Z_in(Zflag).
		.N_in(Nflag),
		.alu_result_in(alu_result),
		.rt_in(idex_rt),
		.rd_in(idex_rd),
		.pc_plus_imm_in(pc_plus_imm),
		.aluOp_in(idex_ctrl[11:9]),
		.MemRead_in(idex_ctrl[8]),
		.MemWrite_in(idex_ctrl[7]),
		.RegWrite_in(idex_ctrl[6]),
		.MemToReg_in(idex_ctrl[5]),
		.PCtoReg_in(idex_ctrl[4]),
		.BrZ_in(idex_ctrl[3]),
		.BrN_in(idex_ctrl[2]),
		.jump_in(idex_ctrl[1]),
		.jump_mem_in(idex_ctrl[0])
		
		.Z_out(Zflag),
		.N_out(Nflag),
		.alu_result_out(exmem_alu_result),
		.rt_out(exmem_rt),
		.rd_out(exmem_rd),
		.pc_plus_imm_out(exmem_pc_plus_imm)
		.aluOp_out(exmem_ctrl[11:9]),
		.MemRead_out(exmem_ctrl[8]),
		.MemWrite_out(exmem_ctrl[7]),
		.RegWrite_out(exmem_ctrl[6]),
		.MemToReg_out(exmem_ctrl[5]),
		.PCtoReg_out(exmem_ctrl[4]),
		.BrZ_out(exmem_ctrl[3]),
		.BrN_out(exmem_ctrl[2]),
		.jump_out(exmem_ctrl[1]),
		.jump_mem_out(exmem_ctrl[0])

	);
	
	

//===================== Stage 4 (MEM stage) wires and regs =====================
	// data_mem takes in idex_rt, ALU_result, exmem_ctrl[x] for MemR and exmem_ctrl[2] for MemW
	wire mem_data_out;

	//intermediate stuff
	//instantiate the OR gate to choose between Z and N, and one more OR to choose between BrZ and BrN. 
	//or gate inputs are zflag and nflag from ex/mem
	wire or_alu_flags_out
	
	//second or gate inputs are BrZ and BrN from control unit
	wire or_branch_signals_out;
	
	
	//Then the results of these go to an AND, and the output of the AND is the select line for the PC mux
	wire pc_sel;
	
	// MEM/WB buffer inputs are exmem_ALU_result, data_mem_out, and exmem_ctrl
	wire [5:0] memwb_rd;

	wire [31:0] memwb_data_out; //this is the jmp signal 
	wire [31:0] memwb_alu_result; 
	
// Instantiate stage 4 (MEM stage) modules
	data_mem data_mem(
		.clk(clk), 
		.r(exmem_ctrl[7]),  //MemRead
		.w(exmem_ctrl[6]),  //MemWrite
		.addr(exmem_alu_result_out), 
		.data_in(exmem_rt), 
		.data_out(mem_data_out)
	);
	
	assign or_alu_flags_out = Zflag || Nflag;
	
	assign or_branch_signals_out = exmem_ctrl[3] || exmem_ctrl[2];

	assign pc_sel = or_alu_flags_out && or_branch_signals_out;
	
	//Option 1: Two versions again with different ways to call ctrl
	memwb_buf memwb(
		.clk(clk),
		.data_in(mem_data_out),
		.alu_result_in(exmem_alu_result),
		.rd_in(exmem_rd),
		.ctrl_in(exmem_ctrl[6:0]),
		
		.data_out(memwb_data_out),
		.alu_result_out(memwb_alu_result),
		.rd_out(memwb_rd)
		.ctrl_out(memwb_ctrl[6:0])
	);
	
	//Option 2
	memwb_buf memwb2(
		.clk(clk),
		.data_in(mem_data_out),
		.alu_result_in(exmem_alu_result),
		.rd_in(exmem_rd),
		.RegWrite_in(exmem_ctrl[6]),
		.MemToReg_in(exmem_ctrl[5]),
		.PCtoReg_in(exmem_ctrl[4]),
		.BrZ_in(exmem_ctrl[3]),
		.BrN_in(exmem_ctrl[2]),
		.jump_in(exmem_ctrl[1]),
		.jump_mem_in(exmem_ctrl[0]),
		
		.data_out(memwb_data_out),
		.alu_result_out(memwb_alu_result),
		.rd_out(memwb_rd)
		.RegWrite_out(memwb_ctrl[6]),
		.MemToReg_out(memwb_ctrl[5]),
		.PCtoReg_out(memwb_ctrl[4]),
		.BrZ_out(memwb_ctrl[3]),
		.BrN_out(memwb_ctrl[2]),
		.jump_out(memwb_ctrl[1]),
		.jump_mem_out(memwb_ctrl[0])
	);
	
	

//===================== Stage 5 (WB stage) wires and regs =====================
	wire [31:0] wb_data;
	
	mux3to1 wb_mux(
		.a(pc_plus_imm),
		.b(memwb_alu_result),
		.c(mem_data_out),
		.sel1(memwb_ctrl[5]),
		.sel2(memwb_ctrl[4]),
		.out(wb_data)
	);
	
endmodule
