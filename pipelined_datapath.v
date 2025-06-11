module pipelined_datapath(input clk, input reset);
//===================== Stage 1 (IF stage) =====================
// Instatiate stage 1 (IF stage) modulesMore actions
    // pc
	wire [31:0] pc_in, pc_out; //PC output
	PC program_counter(
		.clk(clk), 
		.in(pc_in),
		.out(pc_out)
	);

    // pc_adder inputs are the PC_out, 1, and outputs pc_plus1
	wire [31:0] pc_plus1;
	pc_p1 pc_add_unit(
		.pc_in(pc_out), 
		.pc_out(pc_plus1)
	);

    // inst_mem takes in PC_out amd outputs inst_out
	wire [31:0] inst_out;
	inst_mem inst_mem(
		.clk(clk), 
		.addr(pc_out),
		.inst(inst_out)
	);
	
    // IF/ID buffer takes in PC, and inst out, and outputs ifid_pc and ifid_instr
	wire [31:0] ifid_pc_plus1, ifid_instr, ifid_pc;
    ifid_buf ifid(
		.clk(clk),
		.instr_in(inst_out),
		.pc_plus1_in(pc_plus1),
		.pc_in(pc_out),
		
		.instr_out(ifid_instr),
		.pc_plus1_out(ifid_pc_plus1),
		.pc_out(ifid_pc)
	);

//===================== Stage 2 (ID stage) wires and regs =====================
// Instantiate stage 2 (ID stage) modules	
    // control unit
	wire [12:0] ctrl_out;
    ControlUnit ctrl_unit(
		.opcode(ifid_instr[31:28]),
		.ctrl_out(ctrl_out)
	);	
	
	// imm gen
	wire [31:0] imm_out;
	imm_gen imm_gen(
		.instruct_in(ifid_instr),
		.instruct_out(imm_out),
		.clk(clk)
	);

    // reg file
	wire [31:0] wb_data;
	wire [5:0] ifid_rs_reg = ifid_instr[21:16];
	wire [5:0] ifid_rt_reg = ifid_instr[15:10];
	wire [31:0] regfile_rs_val, regfile_rt_val; // Register file outputs
	wire [5:0] exmemwb_rd_reg;
	reg_file reg_file(
		.clk(clk), .wrt(ctrl_out[6]), .rd(exmemwb_rd_reg), // exmem_rd is the destination register for writeback
		.rs(ifid_rs_reg), .rt(ifid_rt_reg), .data_in(wb_data),
		.rs_out(regfile_rs_val), .rt_out(regfile_rt_val)
	);

    // ID/EX buffer outputs
	wire [31:0] idex_rs, idex_rt;
	wire [5:0] idex_rd;
	wire [31:0] idex_imm;
	wire [31:0] idex_pc;
	wire [12:0] idex_ctrl;
	// ID/EX buffer outputs (Control)
	wire [2:0] idex_aluOp;
	wire idex_useImm, idex_MemRead, idex_MemWrite, idex_RegWrite, idex_MemToReg, idex_PCtoReg;
	wire idex_BrZ, idex_BrN, idex_jump, idex_jump_mem;
	idex_buf idex(
		.clk(clk),
		.pc_in(ifid_pc),
		.rs_in(regfile_rs_val), // Value of rs from reg file
		.rt_in(regfile_rt_val), // Value of rt from reg file
		.rd_in(ifid_instr[27:22]),
		.imm_in(imm_out),
		//ctrl inputs
		.aluOp_in(ctrl_out[12:10]),
		.useImm_in(ctrl_out[9]),
		.MemRead_in(ctrl_out[8]),
		.MemWrite_in(ctrl_out[7]),
		.RegWrite_in(ctrl_out[6]),
		.MemToReg_in(ctrl_out[5]),
		.PCtoReg_in(ctrl_out[4]),
		.BrZ_in(ctrl_out[3]),
		.BrN_in(ctrl_out[2]),
		.jump_in(ctrl_out[1]),
		.jump_mem_in(ctrl_out[0]),
		
		.pc_out(idex_pc),
		.rs_out(idex_rs),
		.rt_out(idex_rt),
		.rd_out(idex_rd),
		.imm_out(idex_imm),
		//ctrl outputs
		.aluOp_out(idex_aluOp),
		.useImm_out(idex_useImm),
		.MemRead_out(idex_MemRead),
		.MemWrite_out(idex_MemWrite),
		.RegWrite_out(idex_RegWrite),
		.MemToReg_out(idex_MemToReg),
		.PCtoReg_out(idex_PCtoReg),
		.BrZ_out(idex_BrZ),
		.BrN_out(idex_BrN),
		.jump_out(idex_jump),
		.jump_mem_out(idex_jump_mem)
	);
	
	assign idex_ctrl = {
		idex_aluOp, idex_useImm, idex_MemRead, idex_MemWrite, idex_RegWrite,
		idex_MemToReg, idex_PCtoReg, idex_BrZ, idex_BrN,
		idex_jump, idex_jump_mem
	};
	
	wire BrZ_mux_out;
	wire Zflag;
	mux2to1 #(.inputBitSize(1)) BrZ_mux (
	   .a(1),
	   .b(Zflag),
	   .sel(ctrl_out[3]),
	   .out(BrZ_mux_out)
	);
	
    wire BrN_mux_out;
	wire Nflag;
	mux2to1 #(.inputBitSize(1)) BrN_mux(
	   .a(1),
	   .b(Nflag),
	   .sel(ctrl_out[2]),
	   .out(BrN_mux_out)
	);
	
	//Or BrZ_mux_out, BrN_mux_out, jump control signal
	assign or_result = BrZ_mux_out || BrN_mux_out || ctrl_out[1];
	
	wire [31:0] jump_mem_mux_out;	
	mux2to1 #(.inputBitSize(32)) jump_mem_mux(
	   .a(regfile_rs_val),
	   .b(data_mem_out),
	   .sel(ctrl_out[0]),
	   .out(jump_mem_mux_out)
	);
	
	mux2to1 #(.inputBitSize(32)) pc_plus1_mux(
	   .a(jump_mem_mux_out),
	   .b(ifid_pc_plus1),
	   .sel(or_result),
	   .out(pc_in)
	);
	
//===================== Stage 3 (EX/MEM stage) wires and regs ====================;
// Instantiate stage 3 modules
    wire [31:0] pc_mux_choice;
    mux2to1 #(.inputBitSize(32)) alu_src_mux_pc_or_rs(
        .a(idex_rs),
        .b(idex_pc),
        .sel(idex_PCtoReg),
        .out(pc_mux_choice)
    );
      
	wire [31:0] imm_mux_choice;
    mux2to1 #(.inputBitSize(32)) alu_src_mux_imm_or_rt(
        .a(idex_rt), // Immediate as B input for I-type (LD, ST)
		.b(idex_imm),
		.sel(idex_useImm), // Control signal to choose immediate
		.out(imm_mux_choice)
	);
    
    wire [31:0] alu_result;
	ALU ex_alu(
		.A(pc_mux_choice), .B(imm_mux_choice), 
		.aluop(idex_aluOp),
		.out(alu_result), .Z(Zflag), .N(Nflag)
	);

    wire [31:0] adder_pc_plus_imm;
	pc_imm_adder branch_target_calc(
		.pc_in(idex_pc), 
		.imm(idex_imm), 
		.pc_target(adder_pc_plus_imm)
	);

    wire [31:0] data_mem_out;
    data_mem data_mem(
		.clk(clk), 
		.r(idex_MemRead), // MemRead
		.w(idex_MemWrite), // MemWrite
		.addr(alu_result), // ALU result is the address
		.data_in(idex_rt), // rt value is data to write for ST
		.data_out(data_mem_out)
	);

	// EX/MEM outputs
	wire [31:0] exmemwb_alu_result, exmemwb_data_mem_out, exmemwb_pc_plus_imm;
	wire exmemwb_MemToReg;
	exmemwb_buf exmem_lowkey_also_wb(
		.clk(clk),
		.pc_in(adder_pc_plus_imm),
		.rd_in(idex_rd),
		.data_in(data_mem_out),
		.alu_result_in(alu_result),
		.MemToReg_in(idex_MemToReg),
		
		.pc_out(exmemwb_pc_plus_imm),
		.rd_out(exmemwb_rd_reg),
		.data_out(exmemwb_data_mem_out),
		.alu_result_out(exmemwb_alu_result),
		.MemToReg_out(exmemwb_MemToReg)
	);


//=================== Stage 4 (WB Stage) ========================
    mux2to1 #(.inputBitSize(32)) wb_mux(
        .a(exmemwb_alu_result),
        .b(exmemwb_data_mem_out),
        .sel(exmemwb_MemToReg),
        .out(wb_data)
    );
endmodule
