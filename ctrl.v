/* This Control Unit is a 16 bit bus where bit
	15:12 = opcode, 
	11:9 = ALUOp (add is 000, negate is 110, sub is 101, nop is 010, pass A is 111)
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
    input [3:0] opcode,              // Only the 4-bit opcode input is needed
    output reg [11:0] ctrl_out       // Full 12-bit control signal
);

    always @(*) begin
        // Default: NOP
        ctrl_out = 12'b010_000000000;  // ALUOp=010 for nop

        case (opcode)
            4'b0000: ctrl_out = 12'b010_000000000; // NOP
            4'b0001: ctrl_out = 12'b000_001000000; // SVPC: RegWrite, ALU add
            4'b0010: ctrl_out = 12'b000_101000000; // LD: RegWrite, MemRead, MemToReg
            4'b0011: ctrl_out = 12'b000_010000000; // ST: MemWrite
            4'b0100: ctrl_out = 12'b000_001000000; // ADD: RegWrite
            4'b0101: ctrl_out = 12'b001_001000000; // INC: RegWrite, ALUOp=001
            4'b0110: ctrl_out = 12'b110_001000000; // NEG: RegWrite, ALUOp=110
            4'b0111: ctrl_out = 12'b101_001000000; // SUB: RegWrite, ALUOp=101
            4'b1000: ctrl_out = 12'b010_000000010; // J: jump
            4'b1001: ctrl_out = 12'b000_101000001; // JM: MemRead + jump_mem
            4'b1010: ctrl_out = 12'b010_000010000; // BRZ: BrZ
            4'b1011: ctrl_out = 12'b010_000001000; // BRN: BrN
        endcase
    end

endmodule


//I didn't use this TT because I just went with the "instantiate each component" route and I haven't figured out how to place this module in since it's tricky to figure out which stage of the variable goes in. Will come back to it when it's not so late.
module PCLogic(PCSel, Z, N, Zflag, Nflag, PC1, rs, jmp_place, PC_next);
    input [1:0] PCSel;
    input Z, N;
    input Zflag, Nflag;
    input [31:0] PC1, rs, jmp_place; //PC + 1, rs value of register, where to jump to
    output reg [31:0] PC_next;

    always @(*) begin
        case (PCSel)
            2'b00: PC_next = PC1;
            2'b01: begin
                if ((Zflag && Z) || (Nflag && N))
                    PC_next = rs;
                else
                    PC_next = PC1;
            end
            2'b10: PC_next = jmp_place;
            default: PC_next = PC1;
        endcase
    end
endmodule
