//when we say like ifid_blah, that means the blah LEAVES the ifid buffer (not enters)

module pipelined_datapath(input clk);
	
//===================== Stage 1 (IF stage) wires and regs =====================
	
	//remember to instantiate the mux that has 3 inputs: PC+1, jump, and rs (from ALU), and outputs pc_in !!!!!!!!!!!!!!
	//PC Sel is created in EXMEM stage

	// pc
	wire [31:0] pc_in, pc_out; //PC output
	
	// pc_adder inputs are the PC_out, 1, and outputs pc_plus1
	wire [31:0] pc_plus1;


	// inst_mem takes in PC_out amd outputs inst_out
	wire [31:0] inst_out;
	
	// IF/ID buffer takes in PC, and inst out, and outputs ifid_pc and ifid_inst
	reg [31:0] ifid_pc, ifid_inst;	
	

	
	
//===================== Stage 2 (ID stage) wires and regs =====================
 	// reg file
	wire [5:0] rd_in, rs_in, rt_in; //rd_in comes from writeback out of the MEM/WB buffer
	wire [31:0] write_data, regW; //write data is the data to write, regW comes from rightmost mux in MEM/WB stage
	wire [31:0] rs_out, rt_out;

	// imm gen
	wire [31:0] imm_out;

 	// control unit
	//CTRL unit is an 8 bit bus where bit 0 = RegWrite, 1 = MemRead, 2 = MemWrite, 3 = MemToReg, 4 = PCtoReg, 5 = BrZ, 6 = BrN, 7= jmp_mem, 8 = INC
	wire [8:0] ctrl;
	wire [2:0] ALUOp; //add is 000, negate is 110, sub is 101, nop is 010, pass A is 111

	// ID/EX buffer inputs
	// (already made) rs_out, rt_out, imm_out, rd, ctrl, ifid_pc

	// ID/EX buffer outputs
	reg [31:0] idex_rs, idex_rt, idex_imm, idex_pc;
	reg [5:0] idex_rd;
	reg [8:0] idex_ctrl;
	reg [2:0] idex_ALU_OP

	
//===================== Stage 3 (EX stage) wires and regs =====================
	// ex_alu_adder takes in: idex_rs, imm_mux_choice, idex_ALU_OP, and outputs Z, N, and 32bit ALU_result
	wire [31:0] imm_mux_choice, ALU_result, pc_branch; //imm_mux_choice is the result of the mux that chooses imm or rt
	

	//dont forget to instantiate the imm_mux
	
	// EX/MEM buffer takes Zflag, Nflag, ALU_result, idex_rt, PC + imm, idex_rd, and idex_ctrl except ALU_OP is dc
	wire Zflag, Nflag;
	wire [31:0] PC_plus_imm;


	//EXMEM outputs
	reg [31:0] exmem_alu_result, exmem_rt, pc_plus_imm;
	reg [5:0] exmem_rd;
	reg [8:0] exmem_ctrl;


//===================== Stage 4 (MEM stage) wires and regs =====================
	// data_mem takes in idex_rt, ALU_result, exmem_ctrl[1] for MemR and exmem_ctrl[2] for MemW
	wire data_mem_out;

	//intermediate stuff
	//instantiate the OR gate to choose between Z and N, and one more OR to choose between BrZ and BrN. 
		//Then the results of these go to an AND, and the output of the AND is the select line for the PC mux
	
	// MEM/WB buffer inputs are exmem_ALU_result, data_mem_out, and exmem_ctrl

	//MEM/WB buffer outputs are RegW from memwb_ctrl[0], PCtoReg from memwb_ctrl[4], PC, memwb_alu_result, memwb_data_mem_out (as jmp signal), memwb_rd;
	reg memwb_regW; //set this to exmem_ctrl[0]
	reg memwb_pc2R; //set this to exmem_ctrl[4]
	reg memwb_mem2r; //this comes out of the mux that selects between PC and register
	reg [5:0] memwb_rd;

	reg [31:0] memwb_data_out; //this is the jmp signal 
	reg [31:0] memwb_alu_result; 

//===================== Stage 5 (WB stage) wires and regs =====================
	wire [31:0] wb_data;
	
	



//EVERYTHTING BELOW THIS ISNT CHECKED YETTTTTTT !!!!!!!!!!!!!!!1


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
