module pipelined_datapath();
	reg clk;
	
	//*** Stage 1 ***
	wire mux_out;
	wire [7:0] pc_out, IF1; //PC output, IF/ID input
	wire [7:0] pc_adder_out;
	wire pc_adder_Z, pc_adder_N;
	wire [31:9] inst_out, IF2; //inst_mem output, IF/ID input
	
	//*** Stage 2 ***
 	// control unit wires
	wire RegWrite, MemRead, MemWrite, ALUSrc, MemToReg;
	wire [1:0] PCSel;
	wire Zflag, Nflag, add, inc, neg, sub;
	// reg file
	wire [11:0] rs_out, ID5; //reg_file output, ID/EX input
	wire [11:0] rt_out, ID6; //reg_file output, ID/EX input
	// imm gen
	wire [31:0] imm_out, ID7; //imm_gen output, ID/EX input
	// other ID/EX buffer wires
	wire [31:0] ID4;  //pc_out
	wire [5:0] ID9;  //rd_out
	//do we need ID8? Its the func3 thing in the instruction format
	
	//*** Stage 3 ***
	// adder ALU
	wire mux_out;
	wire [31:0] adder_out, EX3;
	wire adder_Z, adder_N;  //do we need z and N flag for adder alu?
	// ALU
	wire [31:0] alu_out, EX5;
	wire alu_Z, EX4, alu_N;
	// other EX/MEM buffer wires
	wire EX1, EX2;  //WB, M
	wire [31:0] EX6;  //rt_out
	wire [5:0] EX7;  //rd_out
	
	//*** Stage 4 ***
	// data_mem
	wire data_out, D2;
	// other MEM/WB buffer wires
	wire D1;  //WB
	wire [31:0] D3;  //alu_out_out
	wire [5:0] D4;  //rd_out
	
	//*** Stage 5 ***
	wire mux_out;
	
	
	//not sure about the instatiation of the parameters below, will come back and fix
	MUX mux(a, b, c, d, sel, mux_out);
	PC program_counter(clk, pc_in[7:0], pc_out);
	inst_mem inst_mem(clk, pc_out, inst_out);
	ALU pc_adder(A, B, add, inc, neg, sub, pc_adder_out, pc_adder_Z, pc_adder_N);
	
	ifid_buf ifid(clk, instr_in, pc_in, IF2, IF1);	
	
	ControlUnit ctrl_unit(opcode, RegWrite, MemRea, MemWrite, ALUSrc, MemToReg, PCSel, Zflag, Nflag, add, inc, neg, sub);
	reg_file reg_file(clk, wrt, rd, rs, rt, data_in, rs_out, rt_out);
	imm_gen imm_gen(clk, imm_in[31:0], imm_out);
	
	idex_buf idex(clk, pc_in, rs_in, rt_in, rd_in, ID5, ID6, ID9, ID4);
		
	ALU adder_alu(A, B, add, inc, neg, sub, adder_out, adder_out_Z, adder_out_N);
	MUX mux(a, b, c, d, sel, mux_out);
	ALU alu(A, B, add, inc, neg, sub, alu_out, alu_Z, alu_N);
	
	exmem_buf exmem(clk, pc_in, alu_out_in, rt_in, rd_in, EX3, EX5, EX6, EX7);
	
	data_mem data_mem(clk, r, w, addr, data_in, data_out);
	
	memwb_buf memwb(clk, data_in, alu_out_in, rd_in, D2, D3, D4);
	
	MUX mux(a, b, c, d, sel, mux_out);
	
	
