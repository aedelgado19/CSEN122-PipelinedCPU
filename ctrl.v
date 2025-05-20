//this is new - it's the PC logic to control the PC selection and also the ctrl signals

module ControlUnit(opcode, RegWrite, MemRead, MemWrite, ALUSrc, MemToReg, PCSel, Zflag, Nflag, add, inc, neg, sub);
    input [3:0] opcode;
    output reg RegWrite, MemRead, MemWrite, ALUSrc, MemToReg;
    output reg [1:0] PCSel;
    output reg Zflag, Nflag, add, inc, neg, sub;

    always @(*) begin

	//init all to 0
        RegWrite = 0; 
	MemRead = 0; 
	MemWrite = 0; 
	ALUSrc = 0; 
	MemToReg = 0;
        PCSel = 2'b00; 
	Zflag = 0; 
	Nflag = 0;
        add = 0; 
	inc = 0; 
	neg = 0; 
	sub = 0;

        case (opcode)
            4'b0000: ; // NOP
            4'b0001: begin // SVPC
                RegWrite = 1;
                ALUSrc = 1;
                add = 1;
            end
            4'b0010: begin // LD
                RegWrite = 1; 
		MemRead = 1;
		MemToReg = 1;
                add = 1;
            end
            4'b0011: begin // ST
                MemWrite = 1;
                add = 1;
            end
            4'b0100: begin // ADD
                RegWrite = 1;
                add = 1;
            end
            4'b0101: begin // INC
                RegWrite = 1; ALUSrc = 1;
                inc = 1;
            end
            4'b0110: begin // NEG
                RegWrite = 1;
                neg = 1;
            end
            4'b0111: begin // SUB
                RegWrite = 1;
                sub = 1;
            end
            4'b1000: PCSel = 2'b01; // J
            4'b1001: begin // JM
                MemRead = 1;
                PCSel = 2'b10;
                add = 1;
            end
            4'b1010: begin // BRZ
                Zflag = 1;
                PCSel = 2'b01;
            end
            4'b1011: begin // BRN
                Nflag = 1;
                PCSel = 2'b01;
            end
        endcase
    end
endmodule

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
