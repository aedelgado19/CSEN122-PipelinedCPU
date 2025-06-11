//module to do pc plus 1
module pc_p1(input [31:0] pc_in, output [31:0] pc_out);
    assign pc_out = pc_in + 1;
endmodule

//PC + imm
module pc_imm_adder(input [31:0] pc_in, input [31:0] imm, output [31:0] pc_target);
    assign pc_target = pc_in + imm;
endmodule


module ALU (
    input [31:0] A, B,
    input [2:0] aluop,
    output reg [31:0] out,
    output Z, N
);
    wire [31:0] negA, negB;
    assign negA = ~A + 1;
    assign negB = ~B + 1;

    always @(*) begin
        case (aluop)
            3'b000: out = B+A;      
            3'b110: out = negB;      
            3'b101: out = B + negA;  
            3'b111: out = A;  
            default: out = 32'b0;    
        endcase
    end

    assign Z = (out == 32'b0);
    assign N = out[31];
endmodule
