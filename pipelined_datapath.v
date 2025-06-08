//when we say like ifid_blah, that means the blah LEAVES the ifid buffer (not enters)

module pipelined_datapath(input clk);
	// making these first so the file compiles:
	//MEM/WB buffer inputs are exmem_ALU_result, data_mem_out, and exmem_ctrl
	wire [5:0] memwb_rd;
	wire [31:0] wb_data;
	wire [6:0] memwb_ctrl;
	wire [1:0] pc_sel;
	wire exmem_jump, exmem_jump_mem;
//===================== Stage 1 (IF stage) =====================
	wire sel1 = exmem_jump;
	wire sel2 = memwb_ctrl[0];

	// pc
	wire [31:0] pc_in, pc_out; //PC output
	
	// pc_adder inputs are the PC_out, 1, and outputs pc_plus1
	wire [31:0] pc_plus1;

	// inst_mem takes in PC_out amd outputs inst_out
	wire [31:0] inst_out;
	
	// IF/ID buffer takes in PC, and inst out, and outputs ifid_pc and ifid_instr
	wire [31:0] ifid_pc, ifid_instr;	
	

// Instatiate stage 1 (IF stage) modules
	mux3to1 pc_mux(
		.a(pc_plus1), 
		.b(exmem_alu_result),
		.c(memwb_data_out),
		.sel1(sel1),  	//pc_sel from mem stage (stage 4), the or and and gates
		.sel2(sel2),	//jump_mem control signal
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
		.add(1'b0), .inc(1'b1), .neg(1'b0), .sub(1'b0),
		.out(pc_plus1), .Z(), .N()
	);
	ifid_buf ific(
		.clk(clk),
		.instr_in(inst_out),
		.pc_in(pc_out),
		
		.instr_out(ifid_instr),
		.pc_out(ifid_pc)
	);
	
	
//===================== Stage 2 (ID stage) wires and regs =====================
 	// reg file
	wire [5:0] rd_in, rs_in, rt_in; //rd_in/memwb_rd comes from writeback out of the MEM/WB buffer
	wire [31:0] write_data;
	wire regW; //write data is the data to write, regW comes from stage 5
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
	wire [11:0] idex_ctrl;
	

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
		.in(ifid_instr), 
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
	wire [31:0] imm_mux_choice; //imm_mux_choice is the result of the mux that chooses imm or rt
	
	//ALUOp
	wire ex_add, ex_inc, ex_neg, ex_sub;
	

	//select between imm or rt mux (0 = rt and 1 = imm)
	wire ALUsrc;
	assign ALUsrc = (idex_ctrl[8] || idex_ctrl[7]);  // ALUsrc = 1 if MemRead or MemWrite

	
	// EX/MEM buffer takes Zflag, Nflag, alu_result, idex_rt, PC + imm, idex_rd, and idex_ctrl except ALU_OP is dc
	wire Zflag, Nflag;
	wire [31:0] pc_plus_imm;


	//EXMEM outputs
	wire [31:0] exmem_alu_result, exmem_rt, exmem_pc_plus_imm;
	wire [5:0] exmem_rd;
	wire [8:0] exmem_ctrl;



	//separate EX/MEM control wires
	wire [2:0] exmem_aluOp;
	wire exmem_memRead, exmem_memWrite, exmem_regWrite;
	wire exmem_memToReg, exmem_pcToReg, exmem_brZ, exmem_brN;

	wire exmem_Z, exmem_N;



	//decode idex_ctrl into ALU signals
	assign ex_add = (idex_ctrl[11:9] == 3'b000);
	assign ex_sub = (idex_ctrl[11:9] == 3'b001);
	assign ex_inc = (idex_ctrl[11:9] == 3'b010);
	assign ex_neg = (idex_ctrl[11:9] == 3'b011);
	
	// Instantiate stage 3 (EX stage) modules
	ALU ex_alu(
		.A(idex_rs), .B(imm_mux_choice), 
		.add(ex_add), .inc(ex_inc), .neg(ex_neg), .sub(ex_sub),
		.out(alu_result), .Z(Zflag), .N(Nflag)
	);
	mux2to1 alu_src_mux(
		.a(idex_rt), 
		.b(idex_imm), 
		.sel(ALUsrc), //ctrl indexed according to order specified above or in ctrl.v
		.out(imm_mux_choice)
	);
	ALU ex_adder(
		.A(idex_pc), .B(idex_imm),
		.add(1'b1), .inc(1'b0), .neg(1'b0), .sub(1'b0),
		.out(pc_plus_imm), .Z(), .N()
	);
	

	exmem_buf exmem(
	    .clk(clk),
	    //inputs
	    .Z_in(Zflag),
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
	    .jump_mem_in(idex_ctrl[0]),

	    //outputs
	    .Z_out(exmem_Z),
	    .N_out(exmem_N),
	    .alu_result_out(exmem_alu_result),
	    .rt_out(exmem_rt),
	    .rd_out(exmem_rd),
	    .pc_plus_imm_out(exmem_pc_plus_imm),
	    .aluOp_out(exmem_aluOp),
	    .MemRead_out(exmem_memRead),
	    .MemWrite_out(exmem_memWrite),
	    .RegWrite_out(exmem_regWrite),
	    .MemToReg_out(exmem_memToReg),
	    .PCtoReg_out(exmem_pcToReg),
	    .BrZ_out(exmem_brZ),
	    .BrN_out(exmem_brN),
	    .jump_out(exmem_jump),
	    .jump_mem_out(exmem_jump_mem)
	);

	
	

//===================== Stage 4 (MEM stage) wires and regs =====================
	

	//intermediate stuff
	wire [31:0] mem_data_out;
	//instantiate the OR gate to choose between Z and N, and one more OR to choose between BrZ and BrN. 
	//or gate inputs are zflag and nflag from ex/mem
	wire or_alu_flags_out;
	
	//second or gate inputs are BrZ and BrN from control unit
	wire or_branch_signals_out;
	
	
	//Then the results of these go to an AND, and the output of the AND is the select line for the PC mux

	// data_mem takes in idex_rt, ALU_result, exmem_ctrl[x] for MemR and exmem_ctrl[2] for MemW
	wire [31:0] memwb_data_out; //this is the jmp signal 
	wire [31:0] memwb_alu_result; 
	
// Instantiate stage 4 (MEM stage) modules
	data_mem data_mem(
		.clk(clk), 
		.r(exmem_memRead), 
		.w(exmem_memWrite), 
		.addr(exmem_alu_result), 
		.data_in(exmem_rt), 
		.data_out(mem_data_out)
	);
	
	assign or_alu_flags_out = exmem_Z || exmem_N;
	
	assign or_branch_signals_out = exmem_ctrl[3] || exmem_ctrl[2];

	assign pc_sel = or_alu_flags_out && or_branch_signals_out;
	
	memwb_buf memwb(
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
		.rd_out(memwb_rd),
		.RegWrite_out(memwb_ctrl[6]),
		.MemToReg_out(memwb_ctrl[5]),
		.PCtoReg_out(memwb_ctrl[4]),
		.BrZ_out(memwb_ctrl[3]),
		.BrN_out(memwb_ctrl[2]),
		.jump_out(memwb_ctrl[1]),
		.jump_mem_out(memwb_ctrl[0])
	);
	
	

//===================== Stage 5 (WB stage) wires and regs =====================
	
	
	mux3to1 wb_mux(
		.a(pc_plus_imm),
		.b(memwb_alu_result),
		.c(mem_data_out),
		.sel1(memwb_ctrl[5]),
		.sel2(memwb_ctrl[4]),
		.out(wb_data)
	);
	
endmodule
