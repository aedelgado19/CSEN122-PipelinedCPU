/* This Control Unit is a 17 bit bus where bit
	16:13 = opcode, 
	12:10 = ALUOp (add is 000, negate is 110, sub is 101, nop is 010, A is 111)
	9 = useImm,
	8 = MemRead, 
	7 = MemWrite, 
	6 = RegWrite, 
	5 = MemToReg, 
	4 = PCtoReg, 
	3 = BrZ, 
	2 = BrN, 
	1 = jump, 
	0 = jump_mem, 
*/


module ControlUnit(
    input [3:0] opcode,
    output reg [12:0] ctrl_out
);
    always @(*) begin
        case (opcode)
		4'b0000: ctrl_out = 13'b010_0000_00_0000; // NOP
		4'b1111: ctrl_out = 13'b000_1001_01_0000; // SVPC (RegWrite, PCtoReg) --> pc+imm
        4'b1110: ctrl_out = 13'b000_0101_10_0000; // LD (MemRead, RegWrite, MemToReg) --> mem_data_out
        4'b0011: ctrl_out = 13'b000_0010_00_0000; // ST (MemWrite)
        4'b0100: ctrl_out = 13'b000_0001_00_0000; // ADD (RegWrite)
        4'b0101: ctrl_out = 13'b001_1001_00_0000; // INC (RegWrite, ALUOp=001)
        4'b0110: ctrl_out = 13'b110_0001_00_0000; // NEG (RegWrite, ALUOp=110)
        4'b0111: ctrl_out = 13'b101_0001_00_0000; // SUB (RegWrite, ALUOp=101)
		4'b1000: ctrl_out = 13'b010_0000_00_0010; // J (jump)
		4'b1010: ctrl_out = 13'b000_0100_00_0001; // JM (MemRead, jump_mem)
		4'b1011: ctrl_out = 13'b010_0000_00_0100; // BRN (BrN)
		4'b1001: ctrl_out = 13'b010_0000_00_1000; // BRZ (BrZ = bit 3)
        4'b0001: ctrl_out = 13'b101_0001_00_0000; // MIN (ALUOp=SUB, RegWrite=1) // MIN (not needed)
	    endcase
    end
endmodule
